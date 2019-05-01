import sys
import time
from neo4j.v1 import GraphDatabase
from neo4j.v1 import Record


TIMEOUT     = 10800.0
NEO_URI     = "bolt://localhost:7687"
NEO_USER    = "neo4j"
NEO_PWD     = "benchmark"


def main():
    qfiles = sys.argv[1:]   # List of .cypher files to query
    
    queries = []
    for q in qfiles:
        with open(q) as f:
            queries.append(f.read())
    
    runner = QueryRunner()
    runner.run_queries(queries)
    runner.print_exceptions()


class QueryRunner:
    def __init__(self):
        self.exceptions = []
        self.driver = GraphDatabase.driver(NEO_URI, auth=(NEO_USER, NEO_PWD))
        self.session = self.driver.session()
        warmup_time = self.warmup_db()
        print("DB warmup time = %f" % (warmup_time))
        time.sleep(5)
    
    def run_queries(self, queries, printResult=True):
        matches     = []
        plan_times  = []
        query_times = []

        for q in queries:
            runtime = self.profile_query(q)
            plan_times.append(runtime)

        for q in queries:
            nmatches, runtime = self.run_query(q)
            matches.append(str(nmatches))
            query_times.append(runtime)
            time.sleep(5)

        if printResult:
            print('----------------------------------------')
            print('Results of %d queries' % (len(queries)))
            print("(matches, plan time, query time)") 
            print('----------------------------------------')
            for i in range(len(queries)):
                print("%10s, %.5f, %.5f" % (matches[i], plan_times[i], query_times[i]))
            print('----------------------------------------')


    def warmup_db(self):
        st = time.time()
        tx = self.session.begin_transaction(timeout=TIMEOUT)
        
        try:
            result = tx.run("call apoc.warmup.run(true,true,true)")
            summary = result.summary()
        except Exception as e:
            pass
        
        elapsed = time.time() - st
        tx.close()
        return elapsed
    

    def profile_query(self, q):
        q = "Explain "+q
        st = time.time()
        tx = self.session.begin_transaction(timeout=TIMEOUT)
        try:
            result = tx.run(q)
            summary = result.summary()
        except Exception as e:
            pass
        
        elapsed = time.time() - st
        tx.close()
        return elapsed
        
    
    def run_query(self, q):
        st = time.time()
        tx = self.session.begin_transaction(timeout=TIMEOUT)
        try:
            result = tx.run(q)
            nmatches = result.peek()[0]
            elapsed = time.time() - st
            tx.close()
            return nmatches, elapsed
        except Exception as e:
            elapsed = time.time() - st
            self.exceptions.append(e)
            tx.close()
            return None, elapsed

    
    def print_exceptions(self):
        print("")
        if len(self.exceptions) > 0:
            print("Exceptions")
            print("----------")
            for e in self.exceptions:
                print(e)
                print("")


if __name__ == '__main__':
    main()
