match (n2)--(n3), (n2)--(n4), (n0)--(n5), (n1)--(n5), (n1)--(n6), (n2)--(n6), (n5)--(n7), (n4)--(n8), (n8)--(n9)
where n0.label='15' and n1.label='13' and n2.label='5' and n3.label='1' and n4.label='13' and n5.label='10' and n6.label='19' and n7.label='6' and n8.label='7' and n9.label='15' and not(n0=n9)
return count(n0)
