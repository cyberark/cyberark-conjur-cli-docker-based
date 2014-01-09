module Conjur
  module Audit
    class Follower
      # Initialize a follower that will fetch more records by 
      # calling :block: with options to merge into the options passed
      # to the audit method (eg, limit, offset)
      def initialize &block
        @fetch = block
      end
      
      # Follow audit events, yielding arrays of new events to :block: as 
      # they are fetched.
      def follow &block
        @last_event_id = nil
        
        loop do
          new_events = fetch_new_events
          block.call new_events unless new_events.empty?
          sleep 1 if new_events.empty?
        end
      end
      
      protected
      
      # Fetch all events after @last_event_id, updating it 
      # to point to the last event returned by this method. 
      # May return an empty array if no new events are available.
      def fetch_new_events
        # If @last_event_id is nil just fetch and return the 
        # most recent events, updating @last_event_id
        if @last_event_id.nil?
          events = @fetch.call(offset: 0)
          @last_event_id = events.last['event_id'] unless events.empty?
          return events
        end
        
        # We have a @last_event_id, fetch batches of events until we 
        # find it.
        events = []
        while (index = events.find_index{|e| e['event_id'] == @last_event_id}).nil?
          events = @fetch.call(offset: events.length - 1, limit: 10).reverse.concat events
        end
        
        # Update @last_event_id and return the sliced events, reversing it one
        # last time (because the block given to follow expects events to be reversed)
        @last_event_id = events.last['event_id']
        events[index + 1..-1].reverse
      end
    end
  end
end