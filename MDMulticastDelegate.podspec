Pod::Spec.new do |s|
    s.name = 'MDMulticastDelegate'
    s.version = '1.1.0'
    s.summary = 'Multicast delegate'
    s.homepage = 'https://github.com/ElfSundae/MDMulticastDelegate'
    s.license = 'MIT'
    s.author = { 'MarkeJave' => '308865427@qq.com', 'Elf Sundae' => 'https://0x123.com' }
    s.source = { :git => 'https://github.com/ElfSundae/MDMulticastDelegate.git', :tag => s.version.to_s}
    s.source_files = 'MDMulticastDelegate.{h,m}'
    s.requires_arc = true
    s.frameworks = 'Foundation'
    s.ios.deployment_target = '7.0'
end
