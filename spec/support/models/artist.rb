# frozen_string_literal: true

class Artist
  include Mongoid::Document

  attr_accessor :before_add_called, :after_add_called, :before_add_referenced_called, :after_add_referenced_called, :before_remove_embedded_called, :after_remove_embedded_called, :before_remove_referenced_called, :after_remove_referenced_called

  field :name, type: String

  embeds_many :songs, before_add: [ :before_add_song, Proc.new { |artist, song| song.before_add_called = true } ], before_remove: :before_remove_song
  embeds_many :labels, after_add: :after_add_label, after_remove: :after_remove_label
  has_many :albums, dependent: :destroy, before_add: [:before_add_album, Proc.new { |artist, album| album.before_add_called = true} ], after_add: :after_add_album, before_remove: :before_remove_album, after_remove: :after_remove_album
  belongs_to :band

  before_create :before_create_stub
  after_create :create_songs
  before_save :before_save_stub
  before_destroy :before_destroy_stub
  before_update :before_update_stub

  protected

  def before_create_stub
    true
  end

  def before_update_stub
    true
  end

  def before_update_fail_stub
    throw(:abort)
  end

  def before_save_fail_stub
    throw(:abort)
  end

  def before_create_fail_stub
    throw(:abort)
  end

  def before_save_stub
    true
  end

  def before_destroy_fail_stub
    throw(:abort)
  end

  def before_destroy_stub
    true
  end

  def create_songs
    2.times { |n| songs.create!(title: "#{n}") }
  end

  def before_add_song(song)
    @before_add_called = true
  end

  def after_add_label(label)
    @after_add_called = true
  end

  def before_add_album(album)
    @before_add_referenced_called = true
  end

  def after_add_album(album)
    @after_add_referenced_called = true
  end

  def before_remove_song(song)
    @before_remove_embedded_called = true
  end

  def after_remove_label(label)
    @after_remove_embedded_called = true
  end

  def before_remove_album(album)
    @before_remove_referenced_called = true
  end

  def after_remove_album(album)
    @after_remove_referenced_called = true
  end
end
