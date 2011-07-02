require 'cassandra/0.8'

module ActionController
  module Session
    class CassandraStore < AbstractStore
      include ErrorHelper
      
      def initialize( app, options = {} )
        super
        
        puts options.class

        @keyspace = 'cia'
        @column_family = 'sessions'
        @read_consistency = CassandraThrift::ConsistencyLevel::ONE
        @write_consistency = CassandraThrift::ConsistencyLevel::ALL
        @timeout = 5
        @marshaled_data = nil
        
        create_connection
      end

      def create_connection
        if @client.nil?
          config = ActiveRecord::Base.configurations[:cassandra_sessions.to_s]
          options = { :connect_timeout => @timeout }
                  
          unless config.nil?
            @client = Cassandra.new( @keyspace, "#{config['host']}:#{config['port']}", options )
          else
            @client = Cassandra.new( @keyspace, '127.0.0.1:9160', options )
          end
        end
      end
      
      private
                      
        def get_session( env, sid )
          sid ||= generate_sid
          session_data = {}
        
          ret = @client.get( @column_family, sid.to_s, :consistency => @read_consistency )
        
          if 0 != ret.size 
            @marshaled_data = ActiveSupport::Base64.decode64( ret["data"] )
            session_data = Marshal.load( @marshaled_data )
          end            
        
          [sid, session_data]              
        rescue => e          
          ActionController::Base.logger.error( rescue_msg( e ) )          
        
          [sid, {}]              
        end

        def set_session( env, sid, session_data )
          marshaled_data = Marshal.dump( session_data )

          # only write if the sessions data has changed  
          if marshaled_data != @marshaled_data
            now = Time.now.to_s
        
            @client.insert( @column_family, sid.to_s, { "data" => ActiveSupport::Base64.encode64( marshaled_data ), 
              "updated_at" => now }, :consistency => @write_consistency )
          end  
                  
          true
        rescue => e
          ActionController::Base.logger.error( rescue_msg( e ) )          
        
          false
        end
    end
  end
end