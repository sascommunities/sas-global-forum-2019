match (x)-[:doctoralDegreeFrom|mastersDegreeFrom|undergraduateDegreeFrom]->(y)
where y.id='University0'
return count(x)
