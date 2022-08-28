import org.antlr.runtime.*;
import java.util.ArrayList;
import java.util.List;

public class myCompiler_test {
	public static void main(String[] args) throws Exception {

      CharStream input = new ANTLRFileStream(args[0]);
      myCompilerLexer lexer = new myCompilerLexer(input);
      CommonTokenStream tokens = new CommonTokenStream(lexer);
 
      myCompilerParser parser = new myCompilerParser(tokens);
      parser.program();
      
      /* Output text section */
      List<String> text_code = parser.getTextCode();

      List<String> string_declare = parser.getStringDeclare();

      text_code.add(2, "");

      for (int i=string_declare.size()-1; i >= 0; i--)
         text_code.add(2, string_declare.get(i));
	  
      for (int i=0; i < text_code.size(); i++)
         System.out.println(text_code.get(i));
   }
}
