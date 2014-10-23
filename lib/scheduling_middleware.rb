# Note that this scheduling middleware only works for the FullScannerWorker
# which contains jobs that can potentially take multiple hours to finish.
class SchedulingMiddleware
  def call(worker_instance, msg, queue)
    if msg["class"] == "FullScannerWorker"
      opts = msg["args"].last
      # If start and end time are 0.0, no scheduling was provided. Start the
      # job.
      if opts["utc_start_test"] == 0.0 && opts["utc_end_test"] == 0.0
        yield
      end

      utc_start_time = decimal_to_utc_time(opts["utc_start_test"])
      utc_end_time = decimal_to_utc_time(opts["utc_end_test"])


      time_now = Time.now.utc

      #TODO: don't forget about minutes
      if (0..utc_start_time.hour-1).cover? time_now.hour
        utc_start_time -= 1.day
      else
        # If the end time is less than the start time, add a day as this was
        # meant to be a cross-day timeframe
        utc_end_time += 1.day if utc_end_time < utc_start_time
      end

      unless (time_now.between?(utc_start_time, utc_end_time))
        schedule_time = calculate_processing_time(time_now, utc_start_time)
        Sidekiq.logger.info "SCHEDULING_MIDDLEWARE: postponing for #{schedule_time}"
        worker_instance.class.perform_in(schedule_time, *msg["args"])

        # return false prevents the job from running
        return false
      end
    end

    # Continues execution
    yield
  end

  def decimal_to_utc_time(decimal)
    hour = decimal.to_i
    min = ((decimal-hour) * 60).to_i

    # Used to get the current year, month, and day
    t = Time.now.utc

    Time.utc(t.year, t.month, t.day, hour, min)
  end

  def calculate_processing_time(time_now, start_time)
    if time_now < start_time
      return (start_time - time_now).to_i + 20
    else
      return ((start_time + 1.day) - time_now).to_i + 20
    end
  end
end
