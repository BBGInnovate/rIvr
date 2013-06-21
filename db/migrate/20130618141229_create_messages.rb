class CreateMessages < ActiveRecord::Migration
  def up
      create_table "messages" do |t|
        t.column :name,                      :string
        t.column :description,               :string
        t.timestamps
      end
      [['introduction','Welcome to Mali One'],
        ['press_one','Press 1 to listen to the latest news'],
        ['press_two','Press 2 to record a message'],
        ['press_9_main_menu','Press 9 any time to go to main menu'],
        ['no_input','No input, please try again'],
        ['invalid_input','Invalid input, please try again'],
        ['record_message','Please record the message after the beep. Press any key to end recording'],
        ['save_message','To save this message press 1. To cancel press 2'],
        ['I_heard_you_said','I heard you said '],
        ['recording_saved','Record was saved'],
        ['recording_cancelled','Recording cancelled'],
        ['recording_cant_be_saved','Recording cannot be saved. Please try again later'],
        ['line_busy','Line is busy. '],
        ['thank_you_for_calling','Thank you for listening the messages.'],
        ['goodbye','Goodbye. Thank you for calling']
      
      ].each do |n|
        Message.create :name=>n[0], :description=>n[1]
      end
    end
  
    def down
      drop_table "messages"
    end
end
