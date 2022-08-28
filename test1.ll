; === prologue ====
declare dso_local i32 @printf(i8*, ...)

@.str.0 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.str.1 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.str.2 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define dso_local i32 @main()
{
%t0 = alloca i32, align 4
%t1 = alloca i32, align 4
%t2 = alloca i32, align 4
store i32 0, i32* %t1
store i32 1, i32* %t2
store i32 1, i32* %t0
br label %LL1start
LL1start:
%t3 = load i32, i32* %t0
%t4 = icmp slt i32 %t3, 100
br i1 %t4, label %LL1body, label %LL1end
br label %LL1tail
LL1tail:
%t5 = load i32, i32* %t0
%t6 = add nsw i32 %t5, 2
store i32 %t6, i32* %t0
br label %LL1start
br label %LL1body
LL1body:
%t7 = load i32, i32* %t1
%t8 = add nsw i32 %t7, 3
store i32 %t8, i32* %t1
br label %LL2start
LL2start:
%t9 = load i32, i32* %t2
%t10 = icmp slt i32 %t9, 5
br i1 %t10, label %LL2true, label %LL2end
br label %LL2true
LL2true:
%t11 = load i32, i32* %t1
%t12 = add nsw i32 %t11, 7
store i32 %t12, i32* %t2
br label %LL2start
br label %LL2end
LL2end:
br label %LL1tail
br label %LL1end
LL1end:
%t14 = load i32, i32* %t0
%t13 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.0, i64 0, i64 0), i32 %t14)
%t16 = load i32, i32* %t1
%t15 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.1, i64 0, i64 0), i32 %t16)
%t18 = load i32, i32* %t2
%t17 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.2, i64 0, i64 0), i32 %t18)

; === epilogue ===
ret i32 0
}
