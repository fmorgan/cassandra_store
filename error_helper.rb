module ErrorHelper

  def rescue_msg( e )
    msg = "\n\nnil exception (unknown error)\n\n\n"
  
    unless e.nil?
      # format an error message
      msg = "\n\n#{e.class} (#{e.message}):\n    " + 
            e.backtrace.join("\n    ") + 
            "\n\n"
    end
    
    msg
  end
  
  def rescue_alert( msg )
    # stderr
    $stderr.puts msg
    # logger
    Base.logger.error( msg )
  end
  
  def rescue_msg_and_alert( e )
    m = rescue_msg( e )
    rescue_alert( m )
    
    m
  end
  
end
