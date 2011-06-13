require 'json'

module ActsAsAwardable

  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods

    # acts_as_awardable :delegate_to => :col, :prefix => true/false
    def acts_as_awardable options={}

      raise "ActsAsAwardable don't konw wihci column to delegate to" if options[:delegated_to].blank? 
      if options[:delegate_to].is_a?(Array) && (options[:prefix].blank? || options[:prefix] == false)
        raise "Multiple delegated columns detected, please set :prefix => [:prefix_a, :prefix_b, ..] explictly"  
      end

      delegated_columns = ([] << options[:delegated_to]).flatten
      prefixes = ([] << options[:prefix]).flatten

      delegated_columns.each_with_index do |col, idx|
        prefix = (prefixes[idx].to_s + "_") if prefixes[idx]
        module_eval <<-EOF	
          def #{prefix}award_attributes       
            @#{prefix}award_attributes ||= JSON.parse(self.send("#{col}".to_sym) || '{}')
          end
  
          def #{prefix}award_attributes= values_hash
            result = if values_hash.blank?
              {}
            else 
              transaction do
                #{prefix}award_attributes.delete_if{|k,v| !values_hash.keys.include?(k.to_s) }
                values_hash.each_pair do |award_type,values|
                  #{prefix}award_attributes[award_type.to_s] = values
                end
              end
              values_hash
            end
            self.send("#{col}=", result.to_json)
          end
        EOF
      end

    end

  end

end
