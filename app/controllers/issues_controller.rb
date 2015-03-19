require "json"

class IssuesController < ApplicationController
  before_action :set_issue, only: [:show, :edit, :update, :destroy]

  # GET /issues
  # GET /issues.json
  def index
    @issues = Issue.all
  end

  # TODO modelメソッドへ移す
  def string_week2time(string_time)
    str_arr = string_time.split("/")
    year = str_arr[0].to_i
    month = str_arr[1].to_i
    day = (str_arr[2].delete("w").to_i - 1 ) * 7 + 1
    # day= 1,7,14,21,28が月曜以外は次の週が第N週になる
    date = Time.gm(year, month, day)
    date.monday? ? date : date.next_week
  end

  # TODO modelメソッドへ移す
  def param2week_str(data_params)
    "#{data_params[:year]}/#{data_params[:month]}/#{data_params[:week]}"
  end

  def list
    ba = BacklogApi.new(api_key: ENV["BACKLOG_API_KEY"])
    id = ba.projects[0]["id"]

    mile_stones = ba.versions(id.to_s)

    mile_stone_name = param2week_str(params[:date])
    mile_stone = mile_stones.select { |m| m["name"] == mile_stone_name }.first

    params_bl =  { "projectId[]" => id, "milestoneId[]" => mile_stone["id"], "sort" => "created", "order" => "asc" }
    result = ba.issues(params_bl)

    t = string_week2time(mile_stone_name)

    first_day = t.clone
    vals = {}
    7.times do |a|
      vals.store(t, { day: a, count: 0, inc: 0, dec: 0 } )
      t += 1.day
    end

    result.each do |issue|
      cre = issue["created"]
      cre_day = Time.parse(cre).beginning_of_day
      # 含んでいない場合、過去の場合
      if vals[cre_day].nil? &&  cre_day < vals.first[0]
        vals[first_day][:inc] += 1
      # 含んでいる場合
      else
        vals[cre_day][:inc] += 1
      end

      upd = issue["updated"]
      upd_day = Time.parse(upd).beginning_of_day
      sta = issue["status"]["id"]
      vals[upd_day][:dec] += 1 if sta == 4
    end

    count = 0
    vals.each do |a|
      a[1][:count] = count + a[1][:inc] - a[1][:dec]
      count = a[1][:count]
    end

    val_ticket_num = vals.map do |a|
      { "x" => a[0].strftime("%Y/%m/%d"), "y" => a[1][:count] }
    end

    val_ticket_inc = vals.map do |a|
      { "x" => a[0].strftime("%Y/%m/%d"), "y" => a[1][:inc] }
    end

    val_ticket_dec = vals.map do |a|
      { "x" => a[0].strftime("%Y/%m/%d"), "y" => a[1][:dec] }
    end
    # データのひな形を作る
    data_template = {
      "xScale" => "ordinal",
      "yScale" => "linear",
      "main" => [
        {
          "className" => ".pizza",
          "data" => nil
        }
      ]
    }
    data = []

    data_count = Marshal.load(Marshal.dump(data_template))
    data_count["main"][0]["data"] = val_ticket_num
    data << data_count

    data_inc = Marshal.load(Marshal.dump(data_template))
    data_inc["main"][0]["data"] = val_ticket_inc
    data << data_inc

    data_dec = Marshal.load(Marshal.dump(data_template))
    data_dec["main"][0]["data"] = val_ticket_dec
    data << data_dec

    @vals = data.to_json
    render
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
  end

  # GET /issues/new
  def new
    @issue = Issue.new
  end

  # GET /issues/1/edit
  def edit
  end

  # POST /issues
  # POST /issues.json
  def create
    @issue = Issue.new(issue_params)

    respond_to do |format|
      if @issue.save
        format.html { redirect_to @issue, notice: 'Issue was successfully created.' }
        format.json { render :show, status: :created, location: @issue }
      else
        format.html { render :new }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /issues/1
  # PATCH/PUT /issues/1.json
  def update
    respond_to do |format|
      if @issue.update(issue_params)
        format.html { redirect_to @issue, notice: 'Issue was successfully updated.' }
        format.json { render :show, status: :ok, location: @issue }
      else
        format.html { render :edit }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    @issue.destroy
    respond_to do |format|
      format.html { redirect_to issues_url, notice: 'Issue was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issue
      @issue = Issue.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def issue_params
      params[:issue]
    end
end
