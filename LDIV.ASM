ldiv:
	xor	cx,cx     
	jmp	ldiv2
ludiv:
	mov	cx,0001   
	jmp	ldiv2
lmod:
	mov	cx,0002   
	jmp	ldiv2
lumod:
	mov	cx,0003
ldiv2:
	push	bp        
	push	si        
	push	di        
	mov	bp,sp     
	mov	di,cx     
	mov	ax,[bp+0ah]
	mov	dx,[bp+0ch]
	mov	bx,[bp+0eh]
	mov	cx,[bp+10h]
	or	cx,cx     
	jnz	chksign
	or	dx,dx     
	jz	do16bitdiv
	or	bx,bx     
	jz	do16bitdiv
chksign:
	test	di,1   
	jnz	isunsigned
	or	dx,dx     
	jns	dividendfixed
	neg	dx
	neg	ax        
	sbb	dx,0    
	or	di,0ch
dividendfixed:
	or	cx,cx     
	jns	isunsigned
	neg	cx        
	neg	bx        
	sbb	cx,0    
	xor	di,4			; flag invert answer
isunsigned:
	mov	bp,cx     
	mov	cx,20   
	push	di        
	xor	di,di     
	xor	si,si     
divLoop:
	shl	ax,1      
	rcl	dx,1      
	rcl	si,1      
	rcl	di,1      
	cmp	di,bp     
	jb	nextdivLoop
	ja	reduceDividend
	cmp	si,bx     
	jb	nextdivLoop
reduceDividend
	sub	si,bx     
	sbb	di,bp     
	inc	ax
nextdivLoop:
	loop	divLoop
	pop	bx        
	test	bx,2   
	jz	notmod
	mov	ax,si     
	mov	dx,di     
	shr	bx,1
notmod:      
	test	bx,4
	jz	ldivexit
	neg	dx        
	neg	ax        
	sbb	dx,0    
ldivexit:
	pop	di        
	pop	si        
	pop	bp        
do16bitdiv:
	div	bx        
	test	di,2   
	jz	dontinvert16
	xchg	dx,ax
dontinvert16:
	xor	dx,dx     
	jmp	ldivexit


