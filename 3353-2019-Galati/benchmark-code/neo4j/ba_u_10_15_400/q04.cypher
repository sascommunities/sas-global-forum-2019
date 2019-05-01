match (n1)--(n4), (n4)--(n5), (n2)--(n5), (n0)--(n6), (n2)--(n6), (n1)--(n7), (n3)--(n7), (n3)--(n8), (n0)--(n9)
where n0.label='2' and n1.label='272' and n2.label='211' and n3.label='62' and n4.label='323' and n5.label='96' and n6.label='43' and n7.label='212' and n8.label='255' and n9.label='307'
return count(n0)
