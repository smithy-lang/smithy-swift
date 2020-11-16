Pod::Spec.new do |s|
   s.name         = 'Core'
   s.version      = '1'
   s.summary      = 'Core functionality of an SDK for any API'

   s.description  = 'This pod provides core functionality for any SDK'

   s.homepage     = 'https://example.com/weather'
   s.license      = 'Apache License, Version 2.0'
   s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
   s.platform     = :ios, '11.0'
   s.source       = { :git => 'https://github.com/aws/aws-sdk-ios.git',
                      :tag => s.version}
   s.requires_arc = true
   s.source_files = 'Core/*.swift'
end