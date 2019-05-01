
# Pattern Match Benchmark

This folder contains a files and code used for performance benchmarks of graph pattern matching in SAS, Neo4j, and iGraph. There is a folder corresponding to each framework that contains the code for executing queries. 

The `data` folder contains scripts for processing data into the formats required by each framework. More detailed instructions for obtaining the data and processing it are explained in the following subsections. We did not include processed data sets due to their size, but the scripts provided in this repository are sufficient to reproduce them. However, if you would like to directly access the data, please email Matt Galati (Matthew.Galati@sas.com) or Steve Harenberg (Steven.Harenberg@sas.com).

This repository also contains the table with the complete set of results for the five Neo4j runs in the `neo4j/results.xlsx` file. (Due to space limitations, the paper reported the average of five runs). 



## Data Preparation

The benchmark was performed on three data sources: a real-world amazon dataset, synthetically generated data, and a standardized benchmark (LUBM). The `data` folder contains scripts for processing the raw datasets into files ingestible by the three frameworks.

For this benchmark, SAS and Neo4j use node and link CSV files as inputs, though in slightly different formats. For SAS, the CSV files have a header line that denote column names. For Neo4j, the header information is in separate files (that is, Neo4j ingests four CSV files: a file for nodes, links, and a header file for each). Neo4j also looks for certain keywords. For iGraph, CSV files are not supported, so [GraphML](http://graphml.graphdrawing.org/) files were used.

**NOTE:** Most of the data preparation scripts require iGraph. You will need to install iGraph before running them. Generally, this is fairly simple if you have [pip](https://pypi.org/project/pip/) or an [Anaconda](https://www.anaconda.com/distribution/) installation of Python.


### amazon-meta

The amazon-meta data set is from the SNAP data repository found [here](http://snap.stanford.edu/data/amazon-meta.html). This data set contains product metadata. The `prep_amazon.py` script creates a graph from the raw data and outputs a GraphML file. 

From the data folder do the following:
```
wget http://snap.stanford.edu/data/bigdata/amazon/amazon-meta.txt.gz
gunzip amazon-meta.txt.gz
python prep_amazon.py amazon-meta.txt
```

The `graphml_csv_converter.py` script can then be used to create CSV files in a format for SAS or Neo4j. 

For SAS,
```
python graphml_csv_converter.py amazon-meta.graphml
```

For Neo4j,
```
python graphml_csv_converter.py amazon-meta.graphml --neo4j
```


### Synthetic Graphs

The synthetic graphs are created with the `generate_synthetic_graphs.py` script, which uses the graph generator tools in iGraph. In our benchmark we used two different generation models and varying numbers of unique attribute values (we used a single node attribute).

For the benchmark, we specified 1,000,000 nodes and  15,000,000 links for each synthetic graph (though sometimes you will get a slightly different number of links).

To generate `ba_u_10_15_400` from the paper, for example, do:
```
python generate_synthetic_graphs.py barabasi 1000000 15000000 400 0 ba_u_10_15_400.graphml
```

This will create a GraphML file that can be converted to a CSV file using `graphml_csv_converter.py` as in the previous section.

The parameters to generate each synthetic graph from the paper are as follows:
* *ba_u_10_15_200*:  barabasi 1000000 15000000 200 0 ba_u_10_15_200.graphml
* *ba_u_10_15_400*:  barabasi 1000000 15000000 400 0 ba_u_10_15_400.graphml
* *er_u_10_15_20*:  erdos 1000000 15000000 20 0 er_u_10_15_20.graphml
* *er_u_10_15_30*:  erdos 1000000 15000000 30 0 er_u_10_15_30.graphml
* *er_u_10_15_50*:  erdos 1000000 15000000 50 0 er_u_10_15_50.graphml


### LUBM

The Lehigh University Benchmark (LUBM) generator can be found [here](http://swat.cse.lehigh.edu/projects/lubm/).
```
wget http://swat.cse.lehigh.edu/projects/lubm/uba1.7.zip
unzip uba1.7.zip
```

**OPTIONAL:** There is a bug in the generator regarding linux file paths. The generator will still work and produce files, but the will be saved in the parent directory to where you run the code and with incorrect filenames. You can download the fix and replace the file in the source folder, which requires rebuilding the Java classes.
```
wget http://swat.cse.lehigh.edu/projects/lubm/GeneratorLinuxFix.zip
unzip GeneratorLinuxFix.zip
mv Generator.java src/edu/lehigh/swat/bench/uba/
javac src/edu/lehigh/swat/bench/uba/*.java -d classes/
```

To generate the LUBM data set do the following:
```
java -cp "classes/" edu.lehigh.swat.bench.uba.Generator -onto http://swat.cse.lehigh.edu/onto/univ-bench.owl -univ 50
mkdir lubm_raw
mv University*.owl lubm_raw/
```

The raw RDF data is now in `lubm_raw`. To convert this into CSV files for SAS do the following:
```
python lubm_csv_converter.py lubm_raw/
```
For Neo4j do:
```
python lubm_csv_converter.py lubm_raw/ --neo4j
```

## SAS

The `sas` folder contains three main scripts for running the benchmarks: `lubm.sas`, `amazon-meta.sas`, and `synthetic.sas`. In each of these files, there are a few lines that need to be tailored to your specific environment. 
* The *host*, *port*, and some parameters of the *proc casoperate* command will be specific to your environment and need to be changed. Currently there are dummy variables in these parameters, so the code will not run until these variables are properly set.
* The *csvdir* variable will need to point to the folder containing the csv data. For `synthetic.sas` there are several *csvdir* lines as it runs each of the er_* and ba_* data sets.
* The *nodescsv* and *linkcsv* variables need to match the filenames of the csv data files. For `synthetic.sas` there are several *nodescsv* and *linkcsv* lines as it runs each of the er_* and ba_* data sets.


## Neo4j

### Setup
We used Neo4j 3.5.1 Community Edition and, for reference, the configuration file we used is provided in `neo4j.conf`. This is mostly the default configuration, though we ran memrec (as suggested in the config file) to determine memory values and allowed APOC plugins (for warming up the database).

Our script uses the warmup routine in the APOC plugin. You can download the jar file [here](https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/tag/3.5.0.1). The jar file needs to be placed in the plugins folder of your Neo4j directory.

### Loading Database

The [batch importer](https://neo4j.com/docs/operations-manual/current/tutorial/import-tool/) is the best way to load larger datasets into Neo4j. An example command is given in `load.sh`.

You will still need to start the database before running a query. Your Neo4j configuration file will need to point the proper database before starting (dbms.active_database=graph.db in neo4j.conf). One convenient way to handle this, if you have multiple database, is to simply create a symbolic link from graph.db to whatever database you want to load. For example:
```
ln -s neo4j-community-3.5.1/data/databases/ba_u_10_15_200.db neo4j-community-3.5.1/data/databases/graph.db 
```
This way your configuration file does not need to change.

### Querying

The `cypher_query.py` script executes queries against a running Neo4j database. [The Neo4j Bolt Driver Python package](https://neo4j.com/docs/api/python-driver/current/) is required to run this file. Also, there are few parameters that may need to be tweaked at the top of the file, such as the URI, username, and password for the running database. You can specify a variable number of Cypher queries to run. For example, assuming you are in the `neo4j` folder, you can do:
```
python cypher_query.py ba_u_10_15_200/q01.cypher ba_u_10_15_200/q02.cypher
```



## iGraph

The `igraph_vf2_count.py` script runs a variable number of given queries on a given data graph. It loads the graph, performs the queries on that graph, and reports runtimes and counts. iGraph requires that the attributes of the graphs are converted to integer values (referred to as 'colors').

For example, assume you generated the ba_u_15_200 graph and saved it as `ba_u_10_15_200.graphml`. To run all the queries for `ba_u_10_15_200`, you can do the following:
```
python igraph_vf2_count.py ba_u_10_15_200.graphml ba_u_10_15_200/*.graphml
```
