.data
hello: .asciiz		"Hello world!"

.text

main:
	li $v0, 4
	la $a0, hello
	syscall