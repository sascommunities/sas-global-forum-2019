match 
    (x:GraduateStudent)-[:worksFor|memberOf]->(y:Department),
    (y)-[:subOrganizationOf]->(z:University),
    (x)-[:undergraduateDegreeFrom]->(z)
return count(x)
