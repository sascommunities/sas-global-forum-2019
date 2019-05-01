match (x)-[:takesCourse]->(y:Course)<-[:teacherOf]-(z)
where (x:GraduateStudent or x:UndergraduateStudent) and z.id='Department0.University0.AssociateProfessor0'
return count(x)
