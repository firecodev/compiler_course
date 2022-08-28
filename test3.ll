; === prologue ====
declare dso_local i32 @printf(i8*, ...)

@.str.0 = private unnamed_addr constant [14 x i8] c"Hello World!\0A\00", align 1
@.str.1 = private unnamed_addr constant [9 x i8] c"a is %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [18 x i8] c"a is %d, b is %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [20 x i8] c"arithmetic test %d\0A\00", align 1

define dso_local i32 @main()
{
%t0 = alloca i32, align 4
%t1 = alloca i32, align 4
store i32 8, i32* %t1
%t2 = load i32, i32* %t1
%t3 = add nsw i32 %t2, 7
store i32 %t3, i32* %t0
%t4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([14 x i8], [14 x i8]* @.str.0, i64 0, i64 0))
%t6 = load i32, i32* %t0
%t5 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([9 x i8], [9 x i8]* @.str.1, i64 0, i64 0), i32 %t6)
%t7 = load i32, i32* %t0
%t8 = icmp sge i32 %t7, 15
%t9 = load i32, i32* %t0
%t10 = icmp slt i32 %t9, 20
%t11 = and i1 %t8, %t10
br i1 %t11, label %IL1true, label %IL1false
br label %IL1true
IL1true:
%t12 = add nsw i32 6, 5
%t13 = mul i32 3, -1
%t14 = mul nsw i32 4, %t13
%t15 = sub nsw i32 %t12, %t14
%t16 = and i32 2, 1
%t17 = add nsw i32 %t15, %t16
store i32 %t17, i32* %t0
br label %IL1end
br label %IL1false
IL1false:
br label %IL1end
IL1end:
%t19 = load i32, i32* %t0
%t20 = load i32, i32* %t1
%t18 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([18 x i8], [18 x i8]* @.str.2, i64 0, i64 0), i32 %t19, i32 %t20)
%t22 = load i32, i32* %t1
%t23 = mul nsw i32 %t22, 2
%t24 = add nsw i32 1, %t23
%t25 = mul i32 3, -1
%t26 = add nsw i32 %t24, %t25
%t21 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([20 x i8], [20 x i8]* @.str.3, i64 0, i64 0), i32 %t26)

; === epilogue ===
ret i32 0
}
