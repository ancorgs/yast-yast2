#! /usr/bin/env rspec

require_relative "test_helper"

require "ui/dialog"

class TestDialog < UI::Dialog
  def dialog_content
    HBox(
      PushButton(Id(:ok), "OK"),
      PushButton(Id(:cancel), "Cancel")
    )
  end

  def ok_handler
    finish_dialog(true)
  end
end

class TestDialog2 < TestDialog
  def dialog_options
    Yast::Term.new(:opt, :defaultsize)
  end
end

class StderrTestDialog < UI::Dialog
  def dialog_content
    PushButton(Id(:ok), "Hello, World!")
  end

  def ok_handler
    $stderr.puts "Something went wrong"
    finish_dialog
  end
end

describe UI::Dialog do
  subject { TestDialog }
  describe ".run" do
    def mock_ui_events(*events)
      allow(Yast::UI).to receive(:UserInput).and_return(*events)
    end

    before do
      Yast.import "UI"
      allow(Yast::UI).to receive(:OpenDialog).and_return(true)
      allow(Yast::UI).to receive(:CloseDialog).and_return(true)
      mock_ui_events(:cancel)
    end

    it "returns value from EventDispatcher last handler" do
      mock_ui_events(:ok)

      expect(subject.run).to eq(true)
    end

    it "opens dialog" do
      expect(Yast::UI).to receive(:OpenDialog).and_return(true)

      subject.run
    end

    it "raise exception if dialog opening failed" do
      allow(Yast::UI).to receive(:OpenDialog).and_return(false)

      expect { subject.run }.to raise_error
    end

    it "ensure dialog is closed even if exception is raised in event loop" do
      mock_ui_events(:invalid_event)
      expect(Yast::UI).to receive(:CloseDialog)

      begin
        subject.run
      rescue
        "expected"
      end
    end

    it "raise NoMethodError if abstract method dialog_content is not implemented" do
      expect { UI::Dialog.run }.to raise_error(NoMethodError)
    end

    it "pass dialog options if defined" do
      expect(Yast::UI).to receive(:OpenDialog).and_return(true)
        .with(Yast::Term.new(:opt, :defaultsize), anything)

      TestDialog2.run
    end
  end

  # We do not have a proper ncurses in travis at the moment
  if !ENV["TRAVIS"]
    context "when running the ncurses interface" do
      before(:all) do
        Yast.ui_component = "ncurses"
      end

      before(:each) do
        Yast::UI.OpenUI
      end

      after(:each) do
        Yast::UI.CloseUI
      end

      it "does not fall apart when stderr is used" do
        allow(Yast::UI).to receive(:UserInput).and_return(:ok)
        expect {StderrTestDialog.new.run}.to_not raise_error
      end
    end
  end
end
