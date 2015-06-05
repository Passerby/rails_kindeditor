#coding: utf-8
require "find"
class Kindeditor::AssetsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def create
    imgFile, dir = params[:imgFile], params[:dir]
    unless imgFile.nil?
      bucket = Qiniu::SelfConfig::BUCKET
      put_policy = Qiniu::Auth::PutPolicy.new(bucket)
      date = Time.now
      code, result, response_headers = Qiniu::Storage.upload_with_put_policy(
        put_policy,                # 上传策略
        imgFile.tempfile.path,     # 本地文件名
        "products/#{date.year}/#{date.month}/#{date.day}/#{date.to_i}.#{ imgFile.tempfile.path.gsub(/.*\./,"") }" # 最终资源名，可省略，缺省为上传策略 scope 字段中指定的Key值
      )

      current_url = Qiniu::SelfConfig::DOMAIN
      render json: { error: 0, url: "#{current_url}/#{ result['key'] }" }

    else
      show_error("No File Selected!")
    end
  end

  def list
    bucket = Qiniu::SelfConfig::BUCKET
    current_url = Qiniu::SelfConfig::DOMAIN
    qiniu_list_policy = Qiniu::Storage::ListPolicy.new(bucket, 1000, params[:path], '/')
    code, result, response_headers = Qiniu::Storage.list(qiniu_list_policy)

    file_list = []
    unless result["commonPrefixes"].nil?
      result["commonPrefixes"].each do |dir|
        file_list << { is_dir: true, has_file: true, filesize: 0, is_photo: false, filetype: '',
         filename: dir[0..dir.length - 2], datetime: '' }
      end
    end

    unless result["items"].nil?
      result["items"].each do |f|
        file_list << { is_dir: false, has_file: false, filesize: f['fsize'], is_photo: f['mimeType'].include?('image'),
         dir_path: '', filetype: f['key'].gsub(/.*\./,""), filename: f['key'],
         datetime: Time.at(f['putTime']/1000_0000).strftime("%Y-%m-%d %l:%M:%S") }
      end
    end

    @result = {
      moveup_dir_path: '',
      current_dir_path: '',
      current_url: current_url,
      file_list: file_list,
      total_count: file_list.count
    }

    render :text => @result.to_json
  end
  
  private
  def show_error(msg)
    render :text => ({:error => 1, :message => msg}.to_json)
  end
  
end