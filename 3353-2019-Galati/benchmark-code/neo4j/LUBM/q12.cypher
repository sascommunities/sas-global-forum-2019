match (x)-[:worksFor]->(y:Department)-[:subOrganizationOf*1..2]->(uni), (x)-[:headOf]->(z:Department)
where (x:FullProfessor) and uni.id='University0'
return count(x)
