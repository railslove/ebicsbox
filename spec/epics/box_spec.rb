RSpec.describe 'Setup' do
  it 'initializes the namespace' do
    expect(Epics::Box).to be_kind_of(Module)
  end
end
