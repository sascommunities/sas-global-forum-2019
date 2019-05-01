match (x)-[:worksFor|memberOf]->(y:Department)-[:subOrganizationOf*1..2]->(z)
where (x:GraduateStudent or x:UndergraduateStudent) and z.id='University0'
return count(x)
