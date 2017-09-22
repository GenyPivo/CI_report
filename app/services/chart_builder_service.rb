require 'csv'

class ChartBuilderService
  FAILED_LABEL = 'Failed builds'.freeze
  PASSED_LABEL = 'Passed builds'.freeze
  DURATION_LABEL = 'Duration, s'.freeze

  def initialize(file)
    @csv = CSV.parse(File.read(file))
    @headers = @csv.shift
  end

  def builds_series
    marked = mark_abnormal
    [
      { name: FAILED_LABEL, data: marked[:failed]},
      { name: PASSED_LABEL, data: marked[:passed]}
    ]
  end

  def duration_series
    [
      {
        name: DURATION_LABEL,
        data: time_and_duration
      }
    ]
  end

  private

  def grouped_data
    @csv.group_by do |row|
      row[index_by_header('summary_status')] == 'passed'
    end
  end

  def index_by_header(header)
    @headers.index(header)
  end

  def build_data_with(passed)
    grouped_data[passed].map do |row|
     [Date.parse(row[index_by_header('created_at')]).to_s, 1]
    end.each_with_object(Hash.new(0)) {|e, h| h[e[0]] += 1}.to_a
  end

  def passed_builds
    build_data_with(true)
  end

  def failed_builds
    build_data_with(false)
  end

  def time_and_duration
    @csv.map do |row|
      [
        DateTime.parse(row[index_by_header('created_at')]).to_s,
        row[index_by_header('duration')].to_s
      ]
    end
  end

  def mark_abnormal
    f_builds = failed_builds
    p_builds = passed_builds
    f_builds.each_with_index do |row, i|
      p = p_builds.detect { |f| f[0] == row[0] }
      if !p || p[1] <= row[1]
        row[0] = '(!)' + row[0]
        p[0] = '(!)' + p[0] if p
      end
    end
    {failed: f_builds, passed: p_builds}
  end
end
