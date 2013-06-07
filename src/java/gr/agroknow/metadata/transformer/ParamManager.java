package gr.agroknow.metadata.transformer;

import net.zettadata.generator.tools.Toolbox;
import net.zettadata.generator.tools.ToolboxException;

public class ParamManager 
{

	public String getLanguageFor( String text )
	{
		if ( forceMtdLanguage != null )
		{
			return forceMtdLanguage ;
		}
		String result = null ;
		if ( mtdLanguage != null )
		{
			result = mtdLanguage ;
		}
		else
		{
			if ( potentialLanguages == null )
			{
				try
				{
					result = Toolbox.getInstance().detectLanguage( text ) ;
				}
				catch ( ToolboxException te){}
			}
			else
			{
				try
				{
					result = Toolbox.getInstance().detectLanguage( text, potentialLanguages ) ;
				}
				catch ( ToolboxException te){}
			}
		}
		return result ;
	}
	
	private String inputFolder = null ;
	public String getInputFolder()
	{
		return inputFolder ;
	}
	
	private String outputFolder = null ;
	public String getOutputFolder()
	{
		return outputFolder ;
	}
	
	private String badFolder = null ;
	public String getBadFolder()
	{
		return badFolder ;
	}
	
	private String set = null ;
	public String getSet()
	{
		return set ;
	}
	
	private String manifestation = null ;
	public String getManifestation()
	{
		return manifestation ;
	}
	
	private String forceMtdLanguage = null ;	
	private String mtdLanguage = null ;
	private String potentialLanguages = null ;
	
	private static ParamManager instance ;
	
	ParamManager()
	{
		
	}
	
	public void setParam(  String[] args  )
	{
		int check = 0 ;
		
		for( int i = 0; i< args.length ; i++ )
		{
			if ( "-input".equals( args[i] ) )
			{
				i++ ;
				inputFolder = args[i] ;
				check = check + 1 ;
			}
			if ( "-output".equals( args[i] ) )
			{
				i++ ;
				outputFolder = args[i] ;
				check = check + 2 ;
			}
			if ( "-bad".equals( args[i] ) )
			{
				i++ ;
				badFolder = args[i] ;
				check = check + 4 ;
			}
			if ( "-set".equals( args[i] ) )
			{
				i++ ;
				set = args[i] ;
				check = check + 8 ;
			}
			if ( "-manifestation".equals( args[i] ) )
			{
				i++ ;
				manifestation = args[i] ;
			}
			if ( "-mtdLanguage".equals( args[i] ) )
			{
				i++ ;
				mtdLanguage = args[i] ;
				check = check + 16 ;
			}
			if ( "-forceMtdLanguage".equals( args[i] ) )
			{
				i++ ;
				forceMtdLanguage = args[i] ;
				check = check + 16 ;
			}
			if ( "-potentialLanguages".equals( args[i] ) )
			{
				i++ ;
				potentialLanguages = args[i] ;
			}
		}
		
		if ( ((args.length % 2) != 0) || !((check == 15 )||(check == 31 ) )  )
		{
			System.err.println( "Usage : java -jar agris2agrif.jar -input <INPUT_FOLDER> -output <OUTPUT_FOLDER> -bad <BAD_FOLDER> -set <SET_NAME> [-manifestation <MANIFESTATION_NAME>] [-mtdLanguage <METADATA_LANGUAGE>|-forceMtdLanguage <METADATA_LANGUAGE>] [-potentialLanguages <LANG1,LANG2,LANGn>]" ) ;
			System.exit( -1 ) ;
		}
	}
	
	public static ParamManager getInstance()
	{
		if (instance == null)
        {
            synchronized(Toolbox.class)
            {
                if (instance == null)
                {
                    instance = new ParamManager() ;
                }
            }
        }
        return instance ;
	}
	
}
