all: antlr-3.5.3-complete.jar myCompiler.g myCompiler_test.java
	java -cp ./antlr-3.5.3-complete.jar org.antlr.Tool myCompiler.g
	javac -cp ./antlr-3.5.3-complete.jar:. myCompilerLexer.java myCompilerParser.java myCompiler_test.java
clean:
	rm -rf *.class myCompilerLexer.java myCompilerParser.java myCompiler.tokens