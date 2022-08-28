grammar myCompiler;

options {
    language = Java;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
}

@members {
    // Type information.
    public enum Type {
        ERR, BOOL, INT, CONST_INT;
    }

    // This structure is used to record the information of a variable or a constant.
    class tVar {
        int     varIndex;   // temporary variable's index. Ex: t1, t2, ..., etc.
        int     iValue;     // value of constant integer. Ex: 123.
    };

    class Info {
        Type theType;   // type information.
        tVar theVar;

        Info() {
            theType = Type.ERR;
            theVar = new tVar();
        }
    };


    // ============================================
    // Create a symbol table.
    // ArrayList is easy to extend to add more info. into symbol table.
    //
    // The structure of symbol table:
    // <variable ID, [Type, [varIndex or iValue, or fValue]]>
    //    - type: the variable type   (please check "enum Type")
    //    - varIndex: the variable's index, ex: t1, t2, ...
    //    - iValue: value of integer constant.
    //    - fValue: value of floating-point constant.
    // ============================================

    HashMap<String, Info> symtab = new HashMap<String, Info>();

    // labelCount is used to represent temporary label.
    // The first index is 0.
    int loopLabelCount = 0;
    int ifLabelCount = 0;

    // varCount is used to represent temporary variables.
    // The first index is 0.
    int varCount = 0;

    // Record all assembly instructions.
    List<String> TextCode = new ArrayList<String>();

    List<String> StringDeclare = new ArrayList<String>();

    int strCounter = 0;


    /*
     * Output prologue.
     */
    void prologue()
    {
        TextCode.add("; === prologue ====");
        TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
        TextCode.add("define dso_local i32 @main()");
        TextCode.add("{");
    }


    /*
     * Output epilogue.
     */
    void epilogue()
    {
        /* handle epilogue */
        TextCode.add("\n; === epilogue ===");
        TextCode.add("ret i32 0");
        TextCode.add("}");
    }


    /* Generate a new label */
    String newLoopLabel()
    {
        loopLabelCount ++;
        return (new String("LL")) + Integer.toString(loopLabelCount);
    }

    String newIfLabel()
    {
        ifLabelCount ++;
        return (new String("IL")) + Integer.toString(ifLabelCount);
    }


    public List<String> getTextCode()
    {
        return TextCode;
    }

    public List<String> getStringDeclare()
    {
        return StringDeclare;
    }
}

program
:   VOID MAIN '(' ')'
        {
            /* Output function prologue */
            prologue();
        }
        '{' 
        declarations
        statements
        '}'
        {
            /* output function epilogue */	  
            epilogue();
        };


declarations
:   type i=Identifier
        {
            if (symtab.containsKey($i.text)) {
                // variable re-declared.
                System.out.println("Type Error: " + 
                                    $i.text + 
                                    ": Redeclared identifier.");
                System.exit(0);
            }

            /* Add ID and its info into the symbol table. */
            Info the_entry = new Info();
            the_entry.theType = $type.attr_type;
            the_entry.theVar.varIndex = varCount;
            varCount ++;
            symtab.put($i.text, the_entry);

            // issue the instruction.
            // Ex: \%a = alloca i32, align 4
            if ($type.attr_type == Type.INT) {
                TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
            }
        }
        (',' j=Identifier
            {
                if (symtab.containsKey($j.text)) {
                    // variable re-declared.
                    System.out.println("Type Error: " + 
                                        $j.text + 
                                        ": Redeclared identifier.");
                    System.exit(0);
                }

                /* Add ID and its info into the symbol table. */
                Info the_entry = new Info();
                the_entry.theType = $type.attr_type;
                the_entry.theVar.varIndex = varCount;
                varCount ++;
                symtab.put($j.text, the_entry);

                // issue the instruction.
                // Ex: \%a = alloca i32, align 4
                if ($type.attr_type == Type.INT) {
                    TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
                }
            }
        )* ';'
        declarations
    |;

type
returns [Type attr_type]
:   INT { $attr_type=Type.INT; };

statements
:   statement statements
    |;

arith_expression
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   lorExpr { $theInfo=$lorExpr.theInfo; };

lorExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=landExpr { $theInfo=$a.theInfo; }
        ( '||' b=landExpr
            {
                if (($theInfo.theType == Type.BOOL) && ($b.theInfo.theType == Type.BOOL)) {
                    TextCode.add("\%t" + varCount + " = or i1 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) || ($b.theInfo.theType == Type.INT) ||
                            ($theInfo.theType == Type.CONST_INT) || ($b.theInfo.theType == Type.CONST_INT)) {
                    System.out.println("or Error: " +
                                        $a.text + "||" + $b.text +
                                        ": Cannot || with numeric result.");
                    System.exit(0);
                } else {
                    System.out.println("or Error: " +
                                        $a.text + "||" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

landExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=borExpr { $theInfo=$a.theInfo; }
        ( '&&' b=borExpr
            {
                if (($theInfo.theType == Type.BOOL) && ($b.theInfo.theType == Type.BOOL)) {
                    TextCode.add("\%t" + varCount + " = and i1 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) || ($b.theInfo.theType == Type.INT) ||
                            ($theInfo.theType == Type.CONST_INT) || ($b.theInfo.theType == Type.CONST_INT)) {
                    System.out.println("and Error: " +
                                        $a.text + "&&" + $b.text +
                                        ": Cannot && with numeric result.");
                    System.exit(0);
                } else {
                    System.out.println("and Error: " +
                                        $a.text + "&&" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

borExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=bandExpr { $theInfo=$a.theInfo; }
        ( '|' b=bandExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = or i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = or i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = or i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = or i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("or Error: " +
                                        $a.text + "|" + $b.text +
                                        ": Cannot or with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("or Error: " +
                                        $a.text + "|" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

bandExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=eqalExpr { $theInfo=$a.theInfo; }
        ( '&' b=eqalExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = and i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = and i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = and i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = and i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("and Error: " +
                                        $a.text + "&" + $b.text +
                                        ": Cannot and with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("and Error: " +
                                        $a.text + "&" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

eqalExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=gtltExpr { $theInfo=$a.theInfo; }
        ( '==' b=gtltExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp eq i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp eq i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("icmp eq Error: " +
                                        $a.text + "==" + $b.text +
                                        ": Cannot icmp eq with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("icmp eq Error: " +
                                        $a.text + "==" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '!=' b=gtltExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp ne i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp ne i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("icmp ne Error: " +
                                        $a.text + "!=" + $b.text +
                                        ": Cannot icmp ne with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("icmp ne Error: " +
                                        $a.text + "!=" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

gtltExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=shifExpr { $theInfo=$a.theInfo; }
        ( '<=' b=shifExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sle i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sle i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("icmp sle Error: " +
                                        $a.text + "<=" + $b.text +
                                        ": Cannot icmp sle with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("icmp sle Error: " +
                                        $a.text + "<=" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '>=' b=shifExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sge i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sge i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("icmp sge Error: " +
                                        $a.text + ">=" + $b.text +
                                        ": Cannot icmp sge with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("icmp sge Error: " +
                                        $a.text + ">=" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '<' b=shifExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp slt i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp slt i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("icmp slt Error: " +
                                        $a.text + "<" + $b.text +
                                        ": Cannot icmp slt with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("icmp slt Error: " +
                                        $a.text + "<" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '>' b=shifExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.BOOL;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("icmp sgt Error: " +
                                        $a.text + ">" + $b.text +
                                        ": Cannot icmp sgt with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("icmp sgt Error: " +
                                        $a.text + ">" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            })*;

shifExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=addiExpr { $theInfo=$a.theInfo; }
        ( '<<' b=addiExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = shl nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = shl nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = shl nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = shl nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("shl Error: " +
                                        $a.text + "<<" + $b.text +
                                        ": Cannot shl with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("shl Error: " +
                                        $a.text + "<<" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '>>' b=addiExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = lshr i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = lshr i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = lshr i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = lshr i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("lshr Error: " +
                                        $a.text + ">>" + $b.text +
                                        ": Cannot lshr with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("lshr Error: " +
                                        $a.text + ">>" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

addiExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=multExpr { $theInfo=$a.theInfo; }
        ( '+' b=multExpr
            {
                // We need to do type checking first.
                // ...

                // code generation.
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    // Update arith_expression's theInfo.
                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    // Update arith_expression's theInfo.
                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("add Error: " +
                                        $a.text + "+" + $b.text +
                                        ": Cannot add with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("add Error: " +
                                        $a.text + "+" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '-' b=multExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("sub Error: " +
                                        $a.text + "-" + $b.text +
                                        ": Cannot sub with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("sub Error: " +
                                        $a.text + "-" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

multExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   a=signExpr { $theInfo=$a.theInfo; }
        ( '*' b=signExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("mul Error: " +
                                        $a.text + "*" + $b.text +
                                        ": Cannot mul with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("mul Error: " +
                                        $a.text + "*" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '/' b=signExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = sdiv i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = sdiv i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("sdiv Error: " +
                                        $a.text + "/" + $b.text +
                                        ": Cannot sdiv with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("sdiv Error: " +
                                        $a.text + "/" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        | '%' b=signExpr
            {
                if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                    TextCode.add("\%t" + varCount + " = srem i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                    TextCode.add("\%t" + varCount + " = srem i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if (($theInfo.theType == Type.BOOL) || ($b.theInfo.theType == Type.BOOL)) {
                    System.out.println("srem Error: " +
                                        $a.text + "\%" + $b.text +
                                        ": Cannot srem with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("srem Error: " +
                                        $a.text + "\%" + $b.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
            }
        )*;

signExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   primaryExpr { $theInfo=$primaryExpr.theInfo; }
    | '-' primaryExpr
        {
                if ($primaryExpr.theInfo.theType == Type.INT) {
                    TextCode.add("\%t" + varCount + " = mul i32 \%t" + $primaryExpr.theInfo.theVar.varIndex + ", -1");

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if ($primaryExpr.theInfo.theType == Type.CONST_INT) {
                    TextCode.add("\%t" + varCount + " = mul i32 " + $primaryExpr.theInfo.theVar.iValue + ", -1");

                    $theInfo.theType = Type.INT;
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                } else if ($primaryExpr.theInfo.theType == Type.BOOL) {
                    System.out.println("-1 Error: " +
                                        "-" + $primaryExpr.text +
                                        ": Cannot -1 with relational result.");
                    System.exit(0);
                } else {
                    System.out.println("-1 Error: " +
                                        "-" + $primaryExpr.text +
                                        ": Unknown Type.");
                    System.exit(0);
                }
        };
		  
primaryExpr
returns [Info theInfo]
@init { $theInfo = new Info(); }
:   Integer_constant
        {
            $theInfo.theType = Type.CONST_INT;
            $theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
        }
    | Identifier
        {
            // get type information from symtab.
            Type the_type = symtab.get($Identifier.text).theType;
            $theInfo.theType = the_type;

            // get variable index from symtab.
            int vIndex = symtab.get($Identifier.text).theVar.varIndex;

            switch (the_type) {
                case INT:
                    // get a new temporary variable and
                    // load the variable into the temporary variable.

                    // Ex: \%tx = load i32, i32* \%ty.
                    TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex);

                    // Now, Identifier's value is at the temporary variable \%t[varCount].
                    // Therefore, update it.
                    $theInfo.theVar.varIndex = varCount;
                    varCount ++;
                    break;
            }
        }
    | '(' arith_expression ')' { $theInfo=$arith_expression.theInfo; };

statement
@init {
        String currentLabel = new String("");
        String ir = new String("");
        String tmpstr = new String("");
        int tmplen = 0;
    }
:   single_statement ';'
    | IF
        {
            currentLabel = newIfLabel();
        }
        '(' arith_expression ')'
        {/* if false jump to Lfalse; */
            if ($arith_expression.theInfo.theType == Type.BOOL) {
                TextCode.add("br i1 \%t" + $arith_expression.theInfo.theVar.varIndex + ", label \%" + currentLabel + "true, label \%" + currentLabel + "false");
                TextCode.add("br label \%" + currentLabel + "true");
                TextCode.add(currentLabel + "true:");
            } else if (($arith_expression.theInfo.theType == Type.INT) ||
                        ($arith_expression.theInfo.theType == Type.CONST_INT)) {
                System.out.println("if Error: " +
                                    $arith_expression.text +
                                    ": Must be boolean result.");
                System.exit(0);
            } else {
                System.out.println("if Error: " +
                                    $arith_expression.text +
                                    ": Unknown Type.");
                System.exit(0);
            }
        }
        statements_block
        {/* jump to Lend; Lfalse:;*/
            TextCode.add("br label \%" + currentLabel + "end");
            TextCode.add("br label \%" + currentLabel + "false");
            TextCode.add(currentLabel + "false:");
        }
        ((ELSE) => else_statement)?
        {/* Lend:; */
            TextCode.add("br label \%" + currentLabel + "end");
            TextCode.add(currentLabel + "end:");
        }
    | FOR
        {
            currentLabel = newLoopLabel();
        }
        '(' single_statement ';'
        {/* Lstart:; */
            TextCode.add("br label \%" + currentLabel + "start");
            TextCode.add(currentLabel + "start:");
        }
        arith_expression ';'
        {/* if false jump to Lend; jump to Lbody; Ltail:;*/
            if ($arith_expression.theInfo.theType == Type.BOOL) {
                TextCode.add("br i1 \%t" + $arith_expression.theInfo.theVar.varIndex + ", label \%" + currentLabel + "body, label \%" + currentLabel + "end");
                TextCode.add("br label \%" + currentLabel + "tail");
                TextCode.add(currentLabel + "tail:");
            } else if (($arith_expression.theInfo.theType == Type.INT) ||
                        ($arith_expression.theInfo.theType == Type.CONST_INT)) {
                System.out.println("for Error: " +
                                    $arith_expression.text +
                                    ": Must be boolean result.");
                System.exit(0);
            } else {
                System.out.println("for Error: " +
                                    $arith_expression.text +
                                    ": Unknown Type.");
                System.exit(0);
            }
        }
        single_statement ')'
        {/* jump to Lstart; Lbody:;*/
            TextCode.add("br label \%" + currentLabel + "start");
            TextCode.add("br label \%" + currentLabel + "body");
            TextCode.add(currentLabel + "body:");
        }
        statements_block
        {/* jump to Ltail; */
            TextCode.add("br label \%" + currentLabel + "tail");
        }
        {/* Lend:; */
            TextCode.add("br label \%" + currentLabel + "end");
            TextCode.add(currentLabel + "end:");
        }
    | WHILE
        {
            currentLabel = newLoopLabel();
        }
        {/* Lstart:; */
            TextCode.add("br label \%" + currentLabel + "start");
            TextCode.add(currentLabel + "start:");
        }
        '(' arith_expression ')'
        {/* if false jump to Lend; */
            if ($arith_expression.theInfo.theType == Type.BOOL) {
                TextCode.add("br i1 \%t" + $arith_expression.theInfo.theVar.varIndex + ", label \%" + currentLabel + "true, label \%" + currentLabel + "end");
                TextCode.add("br label \%" + currentLabel + "true");
                TextCode.add(currentLabel + "true:");
            } else if (($arith_expression.theInfo.theType == Type.INT) ||
                        ($arith_expression.theInfo.theType == Type.CONST_INT)) {
                System.out.println("while Error: " +
                                    $arith_expression.text +
                                    ": Must be boolean result.");
                System.exit(0);
            } else {
                System.out.println("while Error: " +
                                    $arith_expression.text +
                                    ": Unknown Type.");
                System.exit(0);
            }
        }
        statements_block
        {/* jump to Lstart; Lend:; */
            TextCode.add("br label \%" + currentLabel + "start");
            TextCode.add("br label \%" + currentLabel + "end");
            TextCode.add(currentLabel + "end:");
        }
    | BREAK ';'
        {
            TextCode.add("br label \%LL" + Integer.toString(loopLabelCount) + "end");
        }
    | CONTINUE ';'
        {
            TextCode.add("br label \%LL" + Integer.toString(loopLabelCount) + "start");
        }
    | PRINTF
        {
            ir = ir + "\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ";
            varCount ++;
        }
        '(' s=STRING_LITERAL
        {
            tmpstr = $s.text.substring(1, $s.text.length() - 1);
            tmplen = tmpstr.length();
            boolean isFound = true;
            while (isFound) {
                isFound = tmpstr.contains("\\n");
                if (isFound) {
                    tmpstr = tmpstr.replaceFirst("\\\\n", "\\\\0A");
                    tmplen = tmplen - 1;
                }
            }
            tmpstr = tmpstr + "\\00";
            tmplen = tmplen + 1;
            StringDeclare.add("@.str." + Integer.toString(strCounter) + " = private unnamed_addr constant [" + Integer.toString(tmplen) + " x i8] c\"" + tmpstr + "\", align 1");
            ir = ir + "([" + Integer.toString(tmplen) + " x i8], [" + Integer.toString(tmplen) + " x i8]* @.str." + Integer.toString(strCounter) + ", i64 0, i64 0)";
            strCounter ++;
        }
        ( ',' arith_expression
        {
            if ($arith_expression.theInfo.theType == Type.INT) {
                ir = ir + ", i32 \%t" + $arith_expression.theInfo.theVar.varIndex;
            } else if ($arith_expression.theInfo.theType == Type.CONST_INT) {
                ir = ir + ", i32 " + $arith_expression.theInfo.theVar.iValue;
            } else if ($arith_expression.theInfo.theType == Type.BOOL) {
                System.out.println("printf Error: " +
                                    $arith_expression.text +
                                    ": Must be numeric result.");
                System.exit(0);
            } else {
                System.out.println("printf Error: " +
                                    $arith_expression.text +
                                    ": Unknown Type.");
                System.exit(0);
            }
        }
        )* ')' ';'
        {
            ir = ir + ")";
            TextCode.add(ir);
        };

single_statement
:   Identifier '=' arith_expression
        {
            Info theRHS = $arith_expression.theInfo;
            Info theLHS = symtab.get($Identifier.text);

            if (theLHS.theType == Type.CONST_INT) {
                System.out.println("Assign Error: " +
                                    $Identifier.text +
                                    ": Cannot assing to constant.");
                System.exit(0);
            }

            if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)) {		   
                // issue store insruction.
                // Ex: store i32 \%tx, i32* \%ty
                TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex);
            } else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)) {
                // issue store insruction.
                // Ex: store i32 value, i32* \%ty
                TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex);				
            }
        };

statements_block
:   statement
    | '{' statements '}';

else_statement
:   ELSE statements_block;


/* description of the tokens */
INT:    'int';

MAIN: 'main';
VOID: 'void';

IF:         'if';
ELSE:       'else';
FOR:        'for';
WHILE:      'while';
BREAK:      'break';
CONTINUE:   'continue';

PRINTF: 'printf';

STRING_LITERAL: '"' ( EscapeSequence | ~('\\'|'"') )* '"';

Identifier:                 ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:           '0'..'9'+;

WS:( ' ' | '\t' | '\r' | '\n' ) { $channel=HIDDEN; };
COMMENT: '//'(.)*'\n' { $channel=HIDDEN; };
COMMENT_BLOCK:'/*' .* '*/' { $channel=HIDDEN; };


fragment
EscapeSequence: '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\');
