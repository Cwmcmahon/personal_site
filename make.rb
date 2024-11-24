require 'asciidoctor'
require 'pathname'

blog = []
commonplace = []

Pathname.glob("src{/,/*/}*.adoc") {|src_name|
  doc = Asciidoctor.load_file src_name, safe: :unsafe
  out_name = src_name.sub('src/', 'out/').sub_ext('.html')
  if !doc.attributes.fetch('exclude', false) && (!out_name.exist? || out_name.mtime < src_name.mtime)
    Asciidoctor.convert_file src_name, to_file: "#{out_name}", mkdirs: true, base_dir: '.', safe: :unsafe, attributes: 'site-env=true docinfo=shared-header docinfodir=common'
    puts out_name
    if out_name.dirname.basename.to_s == "blog"
      blog.append(src_name)
    elsif out_name.dirname.basename.to_s == "commonplace"
      commonplace.append(src_name)
    end
  end
}

if blog.length != 0
  b_index = "= Blog Posts\n:toc:\n\n"
  blog.sort_by(&:mtime).reverse.each {|src|
    doc = Asciidoctor.load_file src, safe: :unsafe
    title = doc.title
    date = Pathname.new(src).mtime.strftime("%B %d, %Y")
    b_index << "== xref:#{src.basename}[#{title}] (${date})\n\n"
  }
  Asciidoctor.convert b_index, standalone: true, to_file: "out/blog/index.html", safe: :unsafe, attributes: 'site-env=true docinfo=shared-header docinfodir=common'
end

if commonplace.length != 0
  c_index = "= Commonplace Entries\n:toc:\n\n"
  commonplace.sort.each {|src|
    doc = Asciidoctor.load_file src, safe: :unsafe
    title = doc.title
    c_index << "== xref:#{src.basename}[#{title}]\n\n"
  }
  Asciidoctor.convert c_index, standalone: true, to_file: "out/commonplace/index.html", safe: :unsafe, attributes: 'site-env=true docinfo=shared-header docinfodir=common' 
end
