match (x)-[:advisor]->(y)-[:teacherOf]->(z), (x)-[:takesCourse]->(z)
where (x:GraduateStudent or x:UndergraduateStudent) and (y:FullProfessor or y:AssociateProfessor or y:AssistantProfessor or y:Lecturer) and (z:Course or z:GraduateCourse)
return count(x)
