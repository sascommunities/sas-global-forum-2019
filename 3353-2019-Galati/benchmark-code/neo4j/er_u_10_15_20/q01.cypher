match (n0)--(n2), (n2)--(n1), (n1)--(n3), (n2)--(n4)
where n0.label='15' and n1.label='13' and n2.label='10' and n3.label='19' and n4.label='6'
return count(n0)
