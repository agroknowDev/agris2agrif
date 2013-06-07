package gr.agroknow.metadata.transformer.agris2agrif;

import gr.agroknow.metadata.agrif.Agrif;
import gr.agroknow.metadata.transformer.ParamManager;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;

import org.apache.commons.io.FileUtils;


public class Main 
{
	
	public static void main(String[] args) throws IOException
	{
		ParamManager.getInstance().setParam( args ) ;
		
		AGRIS2AGRIF transformer = null ;
		String identifier ;
		File inputDirectory = new File( ParamManager.getInstance().getInputFolder() ) ;
		FileReader fr = null ;
		int wrong = 0 ;
		for (String agris: inputDirectory.list() )
		{
			try
			{
				identifier = agris.substring( 0, agris.length()-4 ) ;
				fr = new FileReader( ParamManager.getInstance().getInputFolder() + File.separator + agris ) ;
				transformer = new AGRIS2AGRIF( fr ) ;
				transformer.setProviderId( ParamManager.getInstance().getSet() ) ;
				transformer.setManifestationType( ParamManager.getInstance().getManifestation() ) ;
				transformer.yylex() ;
				// identifier = transformer.getId() ;
				int iter = 0 ;
				for( Agrif agrif: transformer.getAgrifs() )
				{
					FileUtils.writeStringToFile( new File( ParamManager.getInstance().getOutputFolder() + File.separator + identifier + iter + ".json" ) , agrif.toJSONString() ) ;
					iter++ ;
				}
			}
			catch( Exception e )
			{
				e.printStackTrace() ;
				wrong++ ;
				FileUtils.copyFile( new File( ParamManager.getInstance().getInputFolder() + File.separator + agris) , new File( ParamManager.getInstance().getBadFolder() + File.separator + agris ) )  ;
				System.out.println( "Wrong file : " + agris ) ;
				//e.printStackTrace() ;
				//System.exit( -1 ) ;
			}
			finally
			{
				try 
				{
					fr.close() ;
				} 
				catch (IOException e) 
				{
					e.printStackTrace();
				}
			}
		}
		System.out.println( "#wrong : " + wrong ) ;
	}
}
