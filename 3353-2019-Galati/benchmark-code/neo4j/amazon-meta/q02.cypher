match (n0)--(n2),(n2)--(n4),(n4)--(n5),(n1)--(n6),(n2)--(n6),(n0)--(n7),(n2)--(n7),(n3)--(n7),(n4)--(n7),(n2)--(n8),(n7)--(n8),(n0)--(n9),(n2)--(n9),(n3)--(n9),(n4)--(n9),(n5)--(n9),(n6)--(n9)
where n0.label="Video: Kids & Family" and n1.label="DVD: Kids & Family" and n2.label="DVD: Comedy" and n3.label="Video: Kids & Family" and n4.label="DVD: Kids & Family" and n5.label="Video: Kids & Family" and n6.label="Video: Kids & Family" and n7.label="DVD: Kids & Family" and n8.label="Video: Kids & Family" and n9.label="DVD: Comedy"
and not(n0=n3) and not(n0=n5) and not(n0=n6) and not(n0=n8) and not(n3=n5) and not(n3=n6) and not(n3=n8) and not(n5=n6) and not(n5=n8) and not(n6=n8) and not(n1=n4) and not(n1=n7) and not(n4=n7) and not(n2=n9)
return count(n0)
