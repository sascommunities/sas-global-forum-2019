match (n1)--(n2)--(n3), (n2)--(n4)
where n1.label="Book: Health, Mind & Body" and n2.label="Book: Parenting & Families" and n3.label="Book: Children\'s Books" and n4.label="Book: Home & Garden"
return count(n1)
