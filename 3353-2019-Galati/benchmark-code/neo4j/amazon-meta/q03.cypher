match (n1)--(n3), (n2)--(n3), (n0)--(n4), (n2)--(n5), (n4)--(n7), (n1)--(n8), (n7)--(n8), (n5)--(n9), (n6)--(n9)
where n0.label="Music: Miscellaneous" and n1.label="DVD: Drama" and n2.label="Video: Horror" and n3.label="DVD: Horror" and n4.label="Music: Miscellaneous" and n5.label="DVD: Mystery & Suspense" and n6.label="Book: Mystery & Thrillers" and n7.label="Video: Comedy" and n8.label="DVD: Action & Adventure" and n9.label="DVD: Horror" 
and not(n0=n4) and not(n3=n9)
return count(n0)
