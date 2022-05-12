require 'xcodeproj'

module Constants
  NEED_FIRST_LOAD_FRAMEWORK="Vision"
end

class Xcodeproj::Config
  
  def to_hash(prefix = nil)
    list = []
    list += other_linker_flags[:simple].to_a.sort
    modifiers = {
      :frameworks => '-framework ',
      :weak_frameworks => '-weak_framework ',
      :libraries => '-l',
      :arg_files => '@',
      :force_load => '-force_load',
    }
    [:libraries, :frameworks, :weak_frameworks, :arg_files, :force_load].each do |key|
      modifier = modifiers[key]
      sorted = other_linker_flags[key].to_a.sort
      
      ## 将需要提前+load的库挪到最前面
      if key == :frameworks && sorted.include?(Constants::NEED_FIRST_LOAD_FRAMEWORK)
          sorted.insert(0, "#{sorted.delete(Constants::NEED_FIRST_LOAD_FRAMEWORK)}")
      end

      if key == :force_load
        list += sorted.map { |l| %(#{modifier} #{l}) }
      else
        list += sorted.map { |l| %(#{modifier}"#{l}") }
      end
    end

    result = attributes.dup
    result['OTHER_LDFLAGS'] = list.join(' ') unless list.empty?
    result.reject! { |_, v| INHERITED.any? { |i| i == v.to_s.strip } }

    result = @includes.map do |incl|
      path = File.expand_path(incl, @filepath.dirname)
      if File.readable? path
        Xcodeproj::Config.new(path).to_hash
      else
        {}
      end
    end.inject(&:merge).merge(result) unless @filepath.nil? || @includes.empty?

    if prefix
      Hash[result.map { |k, v| [prefix + k, v] }]
    else
      result
    end
  end

end
