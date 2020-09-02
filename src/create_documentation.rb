require 'json'
require 'markdown_model'

MarkdownModel.skip_models = SkipModels
MarkdownModel.new(RootModel).find_definitions

$logger.info "\nGenerating Devices Markdown to #{DeviceDocumentFile}"
File.open(DeviceDocumentFile, 'w') do |f|
  f.puts "% Generated #{Time.now}"
  
  MarkdownModel.directory = DeviceDirectory
  DeviceModels.each do |m|
    MarkdownModel.generate_markdown(f, m)
  end
end

if false
  $logger.info "\nGenerating Asset Markdown to #{AssetDocumentFile}"
  File.open(AssetDocumentFile, 'w') do |f|
    f.puts "% Generated #{Time.now}"
    
    MarkdownModel.directory = AssetDirectory
    AssetModels.each do |m|
      MarkdownModel.generate_markdown(f, m)
    end
  end
end
