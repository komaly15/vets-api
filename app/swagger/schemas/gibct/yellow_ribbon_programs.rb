# frozen_string_literal: true

module Swagger
  module Schemas
    module Gibct
      class YellowRibbonPrograms
        include Swagger::Blocks

        swagger_schema :GibctYellowRibbonPrograms do
          key :required, %i[data meta links]

          property :data, type: :array, maxItems: 30, uniqueItems: true do
            items do
              key :type, :object
              key :required, %i[id type attributes]

              property :id, type: :string, example: '12345'
              property :type, type: :string, enum: ['yellow_ribbon_programs']
              property :attributes do
                key :required, %i[city
                                  contribution_amount
                                  country
                                  degree_level
                                  division_professional_school
                                  facility_code
                                  institution_id
                                  insturl
                                  number_of_students
                                  school_name_in_yr_database
                                  state
                                  street_address
                                  zip]

                property :city, type: %i[null string], example: 'Chicago',
                                description: 'The city name where the Yellow Ribbon Program is located.'

                property :contribution_amount, type: %i[null string], example: '10000.0',
                                               description: 'The contribution amount in dollars.'

                property :country, type: %i[null string], example: 'USA',
                                   description: 'The country where the Yellow Ribbon Program is located.'

                property :degree_level, type: %i[null string], example: 'All',
                                        description: 'The degree levels available to the Yellow Ribbon Program.'

                property :division_professional_school, type: %i[null string], example: 'All',
                                                        description: 'The majors/minors of the Yellow Ribbon Program.'

                property :facility_code, type: %i[null string], example: '12345',
                                         description: 'The faciliy code of the Yellow Ribbon Program.'

                property :institution_id, type: %i[null integer], example: 12_345,
                                          description: 'The instutition ID the Yellow Ribbon Program belongs to.'

                property :insturl, type: %i[null string], example: 'https://example.com',
                                   description: 'The URL for the Yellow Ribbon Program\'s instutition.'

                property :number_of_students, type: %i[null integer], example: 320,
                                              description: 'The number of students that can receive the benefit.'

                property :school_name_in_yr_database, type: %i[null string], example: 'colorado university',
                                                      description: 'The name of the school.'

                property :state, type: %i[null string], example: 'IL',
                                 description: 'The provincial state where the Yellow Ribbon Program is located.'

                property :street_address, type: %i[null string], example: '1234 Street',
                                          description: 'The street address where the Yellow Ribbon Program is located.'

                property :zip, type: %i[null string], example: '12345',
                               description: 'The zipcode where the Yellow Ribbon Program is located.'
              end
            end
          end

          property :meta, '$ref': :GibctYellowRibbonProgramsMeta
          property :links, '$ref': :GibctYellowRibbonProgramsLinks
        end

        swagger_schema :GibctYellowRibbonProgramsMeta do
          key :type, :object
          key :required, %i[version count]

          property :version, '$ref': :GibctVersion
          property :count, type: :integer, example: 790
        end

        swagger_schema :GibctYellowRibbonProgramsLinks do
          key :type, :object
          key :required, %i[self first prev next last]

          property :self, type: :string
          property :first, type: :string
          property :prev, type: %i[null string]
          property :next, type: %i[null string]
          property :last, type: :string
        end
      end
    end
  end
end