match (x)-[e:worksFor|memberOf]->(y:Department)
where y.id='Department0.University0' and (x:FullProfessor or x:AssociateProfessor or x:AssistantProfessor or x:Lecturer or x:GraduateStudent or x:UndergraduateStudent)
return count(x)
