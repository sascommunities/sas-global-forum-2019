match (x)-[:worksFor]->(y:Department)
where y.id='Department0.University0' and (x:FullProfessor or x:AssociateProfessor or x:AssistantProfessor)
return count(x)
