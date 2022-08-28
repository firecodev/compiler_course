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
%t3 = icmp sgt i32 1, 0
br i1 %t3, label %IL1true, label %IL1false
br label %IL1true
IL1true:
%t4 = icmp sgt i32 1, 2
br i1 %t4, label %IL2true, label %IL2false
br label %IL2true
IL2true:
store i32 9, i32* %t0
%t5 = icmp slt i32 3, 4
br i1 %t5, label %IL3true, label %IL3false
br label %IL3true
IL3true:
store i32 4, i32* %t1
br label %IL3end
br label %IL3false
IL3false:
store i32 5, i32* %t1
br label %IL3end
IL3end:
br label %IL2end
br label %IL2false
IL2false:
store i32 99, i32* %t0
store i32 7, i32* %t1
store i32 6, i32* %t2
br label %LL1start
LL1start:
%t6 = load i32, i32* %t2
%t7 = icmp slt i32 %t6, 20
br i1 %t7, label %LL1true, label %LL1end
br label %LL1true
LL1true:
store i32 50, i32* %t1
br label %LL2start
LL2start:
%t8 = load i32, i32* %t2
%t9 = icmp slt i32 %t8, 10
br i1 %t9, label %LL2body, label %LL2end
br label %LL2tail
LL2tail:
%t10 = load i32, i32* %t1
%t11 = add nsw i32 %t10, 1
store i32 %t11, i32* %t1
br label %LL2start
br label %LL2body
LL2body:
%t12 = load i32, i32* %t2
%t13 = add nsw i32 %t12, 7
store i32 %t13, i32* %t2
br label %LL2tail
br label %LL2end
LL2end:
%t14 = load i32, i32* %t2
%t15 = add nsw i32 %t14, 8
store i32 %t15, i32* %t2
br label %LL1start
br label %LL1end
LL1end:
br label %IL2end
IL2end:
br label %IL1end
br label %IL1false
IL1false:
br label %IL1end
IL1end:
%t17 = load i32, i32* %t0
%t16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.0, i64 0, i64 0), i32 %t17)
%t19 = load i32, i32* %t1
%t18 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.1, i64 0, i64 0), i32 %t19)
%t21 = load i32, i32* %t2
%t20 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.2, i64 0, i64 0), i32 %t21)

; === epilogue ===
ret i32 0
}
