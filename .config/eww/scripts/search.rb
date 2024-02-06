#!/usr/bin/env ruby

require 'pathname'

FILTER = ARGV[0]

if (FILTER.nil? == false and FILTER.empty? == false)
    APPLICATIONS = Dir['/usr/share/applications/*.desktop']
    HOME = File.expand_path('~')
    content = ''

    APPLICATIONS.each do |entry|
        app = File.readlines(entry)

        title = app.find { |element| element.start_with?('Name=') }
        title = title[(title.index('=') + 1)..].strip

        if (title.downcase.include?(FILTER.downcase))
            description = app.find { |element| element.start_with?('GenericName=') } || app.find { |element| element.start_with?('Comment=') } || 'n.a.'
            description = description[(description.index('=') + 1)..].strip unless description == 'n.a.'

            iconName = app.find { |element| element.start_with?('Icon=') } || next
            iconName = iconName[(iconName.index('=') + 1)..].strip
            
            icon = "#{HOME}/.local/share/icons/Tela-circle-orange/scalable/apps/#{iconName}.svg"
            path = Pathname.new(entry)

            content.concat("
                (button :onclick 'gtk-launch #{path.basename} &'

                    (box :orientation 'horizontal'
                        :space-evenly false

                        (image :path '#{icon}')

                        (box :orientation 'vertical'
                            :space-evenly false

                            (label :text '#{title}')

                            (label :text '#{description}')
                        )
                    )
                )
            ")

        end

    end

    %x{ eww update search_content="(box :orientation 'vertical' #{content})" }

else
    %x{ eww update search_content="" }

end