RSpec.describe K8s::KubeConfig do
  it "has a version number" do
    expect(K8s::KubeConfig::VERSION).not_to be nil
  end
end
