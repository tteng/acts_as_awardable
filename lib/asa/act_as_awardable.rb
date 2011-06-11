require 'json'

module ActsAsAwardable

  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods

    # acts_as_awardable :delegate_to => :col, :prefix => true/false
    def act_as_awardable options={}
      raise "ActsAsAwardable don't konw wihci column to delegate to" if options[:delegated_to].blank? 
      if options[:delegate_to].is_a?(Array) && (options[:prefix].blank? || options[:prefix] == false)
        raise "Multiple delegated columns detected, please set :prefix => [:prefix_a, :prefix_b, ..] explictly"  
      end
      write_inheritable_attribute :delegated_columns, ([] << options[:delegated_to]).flatten
      write_inheritable_attribute :prefixes, ([] << options[:prefix]).flatten if options[:prefix]
      class_inheritable_reader :delegated_columns, :prefixes
      include InstanceMethods
    end

  end

  module InstanceMethods
 
    delegated_columns.each_with_index do |col, idx|

      prefix = (prefixes[idx].to_s + "_") if prefixes[idx]

      module_eval <<-EOF	

        def #{prefix}award_attributes       
          @#{prefix}award_attributes ||= JSON.parse(self.send(#{col}) || '{}')
        end

        def #{prefix}award_attributes= values_hash
          result = if some_value.blank?
            {}
          else 
            transaction do
              #{prefix}award_attributes.delete_if{|k,v| !values_hash.keys.include?(k.to_s) }
              values_hash.each_pair do |award_type,values|
                #{prefix}award_attributes[award_type.to_s] = values
              end
            end
          end
        end

        def after_validation
          super
          self.send("#{col}=", @#{prefix}award_attributes.to_json)
        end

      EOF

    end

  end

end
