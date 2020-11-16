Pod::Spec.new do |s|
   s.name         = 'Weather'
   s.version      = '1'
   s.summary      = 'SDK for Weather API'

   s.description  = 'The Weather SDK provides a Weather client to hit the Weather API'

   s.homepage     = 'https://example.com/weather'
   s.license      = 'Apache License, Version 2.0'
   s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
   s.platform     = :ios, '11.0'
   s.source       = { :git => 'https://github.com/aws/aws-sdk-ios.git',
                      :tag => s.version}
   s.requires_arc = true
   s.dependency 'AWSCore', '2.12.7'
   s.source_files = 'Weather/*.swift'
end