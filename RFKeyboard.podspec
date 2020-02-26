Pod::Spec.new do |s|
  s.name             = 'RFKeyboard'
  s.version          = '0.2.0'
  s.summary          = 'iOS Keyboard helper.'

  s.homepage         = 'https://github.com/RFUI/RFKeyboard'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'BB9z' => 'bb9z@me.com' }
  s.source           = { :git => 'https://github.com/RFUI/RFKeyboard.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.ios.deployment_target = '8.0'

  s.source_files = ['RFKeyboard.{h,m}']
  s.public_header_files = ['RFKeyboard.h']
  s.dependency 'RFKit/Runtime', '>= 1.7'

  s.pod_target_xcconfig = {
    # These config should only exsists in develop branch.
    'WARNING_CFLAGS'=> [
      '-Weverything',                   # Enable all possiable as we are developing a library.
      '-Wno-gnu-statement-expression',  # Allow ?: expression.
      '-Wno-gnu-conditional-omitted-operand',
      '-Wno-auto-import',               # Still needs old #import for backward compatibility. 
      '-Wno-sign-conversion',
      '-Wno-sign-compare',
      '-Wno-objc-missing-property-synthesis'
    ].join(' ')
  }
end
