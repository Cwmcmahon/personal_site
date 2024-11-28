require 'asciidoctor'
require 'pathname'
require 'date'

generate_all = (ARGV.length == 1 && ARGV[0] == '-a')

attributes = 'site-env=true docinfo=shared-header docinfodir=common stylesheet=styles/custom.css nofooter'
blog = {}
commonplace = []

Pathname.glob("src{/,/*/}*.adoc") {|src_name|
  doc = Asciidoctor.load_file src_name, safe: :unsafe
  out_name = src_name.sub('src/', 'out/').sub_ext('.html')
  if !doc.attributes.fetch('exclude', false)
    if out_name.dirname.basename.to_s == "blog"
      date = Date.parse(doc.attributes.fetch('date', Date.today.to_s))
      blog.store(src_name, date)
    elsif out_name.dirname.basename.to_s == "commonplace"
      commonplace.append(src_name)
    end
    if !out_name.exist? || out_name.mtime < src_name.mtime || generate_all
      Asciidoctor.convert_file src_name, to_file: "#{out_name}", mkdirs: true, base_dir: '.', safe: :unsafe, attributes: attributes
      puts out_name
    end
  end
}

# Blog index
b_index = "= Blog Posts\n\n"

blog.sort_by(&:last).reverse.to_h.each_pair {|file, date|
  date = date.strftime("%B %d, %Y")
  doc = Asciidoctor.load_file file, safe: :unsafe
  title = doc.title
  b_index << "[discrete]\n=== xref:#{file.basename}[#{title} (#{date})]\n\n"
}

Asciidoctor.convert b_index, standalone: true, to_file: "out/blog/index.html", safe: :unsafe, attributes: attributes

# Commonplace Index
c_index = "= Commonplace\n\n"
cats_txt = "== Categories\n\n"
ents_txt = "== Entries\n\n"
cat_hash = Hash.new { |h,k| h[k] = [] }

commonplace.sort.each {|src|
  doc = Asciidoctor.load_file src, safe: :unsafe
  title = doc.title
  categories = doc.attributes.fetch('categories', '').gsub(' ', '').split(',')
  categories.each {|cat|
    cat_hash[cat] << src
  }
  ents_txt << "=== #{title}\n.Click for full quote\n[%collapsible]\n====\ninclude::#{src}[lines=4..-1]\n====\n\n"
}

cat_hash.sort.to_h.each_pair {|name, arr|
  name_index = "= Commonplace Entries: #{name.capitalize}\n\n"
  arr.each {|src|
    doc = Asciidoctor.load_file src, safe: :unsafe
  	title = doc.title
  	name_index << "[discrete]\n=== #{title}\n.Click for full quote\n[%collapsible]\n====\ninclude::#{src}[lines=4..-1]\n====\n\n"
  }
  Asciidoctor.convert name_index, standalone: true, to_file: "out/commonplace/#{name}.html", safe: :unsafe, attributes: attributes
  cats_txt << "=== xref:#{name}.adoc[#{name.capitalize}]\n\n"
}

c_index << cats_txt + ents_txt

Asciidoctor.convert c_index, standalone: true, to_file: "out/commonplace/index.html", safe: :unsafe, attributes: attributes
