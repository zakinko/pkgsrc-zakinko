# YAML の同じ mapping に同じ key が二度出るのを拾う。
#
# Ruby も Python も後勝ちで黙って通すが、GitHub Actions は workflow ごと
# 拒否する。しかも拒否は「run が jobs 0 件で失敗し、workflow が一覧から
# 消える」という形で出るので、log にも何も残らない。実際に二度、起動すら
# していない run を「走っている」と読んでいた。
#
# 使い方: ruby yaml-dupkey.rb <file>...
require 'psych'

bad = 0
ARGV.each do |path|
  parser = Psych::Parser.new(Psych::TreeBuilder.new)
  parser.parse(File.read(path), path)
  doc = parser.handler.root
  walk = lambda do |node, where|
    case node
    when Psych::Nodes::Stream, Psych::Nodes::Document
      # Stream -> Document -> 実体。ここを素通りすると再帰が一度も走らず、
      # 壊れた file でも「重複なし」と答える。自己試験で見付けた。
      node.children.each { |c| walk.call(c, where) }
    when Psych::Nodes::Mapping
      seen = {}
      node.children.each_slice(2) do |k, v|
        key = k.respond_to?(:value) ? k.value : k.to_s
        if seen[key]
          puts "!! #{path}: #{where} に key '#{key}' が二度 (行 #{seen[key]} と #{k.start_line + 1})"
          bad += 1
        end
        seen[key] = k.start_line + 1
        walk.call(v, "#{where}/#{key}")
      end
    when Psych::Nodes::Sequence
      node.children.each_with_index { |c, i| walk.call(c, "#{where}[#{i}]") }
    end
  end
  walk.call(doc, File.basename(path))
end
puts "重複 key: #{bad}"
exit(bad.zero? ? 0 : 1)
