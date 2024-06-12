a 8000
push cs
pop ds
mov ax,[106]
mov [10c],ax
mov ax,[10a]
mov [10e],ax
sub cx,c
nop

rip
8000
g,8011
w 10c
q


