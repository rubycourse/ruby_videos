module Presenters
  class Create
    include Wisper::Publisher

    attr_reader :form

    def initialize(form)
      @form = form
    end

    def call
      presenter = Presenter.new
      mapper = AutoMapper.new(form, presenter)

      if form.valid?
        presenter = mapper.to_model
        presenter.save
        publish(:ok, presenter)
      else
        publish(:fail)
      end
    end
  end
end
