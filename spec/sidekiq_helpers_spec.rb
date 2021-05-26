# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FatherlyAdvice::SidekiqHelpers::WorkSet, type: :lib do
  describe '.build' do
    let(:generation_time) { Time.new 2021, 5, 19, 17, 12, 6 }
    let(:processes) do
      [
        Sidekiq::Process.new(
          'hostname' => 'virtual-bank-ui-sidekiq-6b84868fc8-lrrhw',
          'started_at' => 1_621_361_767.7182465,
          'pid' => 1,
          'tag' => 'app',
          'concurrency' => 4,
          'queues' => %w[high_priority default low_priority],
          'labels' => ['reliable'],
          'identity' => 'virtual-bank-ui-sidekiq-6b84868fc8-lrrhw:1:e40e1157a14b',
          'busy' => 0,
          'beat' => 1_621_443_631.0711973,
          'quiet' => 'false'
        ),
        Sidekiq::Process.new(
          'hostname' => 'virtual-bank-ui-sidekiq-6b84868fc8-q9nbh',
          'started_at' => 1_621_278_732.7708902,
          'pid' => 1,
          'tag' => 'app',
          'concurrency' => 4,
          'queues' => %w[high_priority default low_priority],
          'labels' => ['reliable'],
          'identity' => 'virtual-bank-ui-sidekiq-6b84868fc8-q9nbh:1:dddae808973b',
          'busy' => 3,
          'beat' => 1_621_443_632.1201744,
          'quiet' => 'false'
        ),
        Sidekiq::Process.new(
          'hostname' => 'virtual-bank-ui-sidekiq-6b84868fc8-t5v6j',
          'started_at' => 1_621_278_734.4830532,
          'pid' => 1,
          'tag' => 'app',
          'concurrency' => 4,
          'queues' => %w[high_priority default low_priority],
          'labels' => ['reliable'],
          'identity' => 'virtual-bank-ui-sidekiq-6b84868fc8-t5v6j:1:63598e6dbe42',
          'busy' => 2,
          'beat' => 1_621_443_628.8127606,
          'quiet' => 'false'
        ),
        Sidekiq::Process.new(
          'hostname' => 'virtual-bank-ui-sidekiq-high-7ddc958bc4-2dqfc',
          'started_at' => 1_621_278_734.7672858,
          'pid' => 1,
          'tag' => 'app',
          'concurrency' => 4,
          'queues' => %w[high_priority default],
          'labels' => ['reliable'],
          'identity' => 'virtual-bank-ui-sidekiq-high-7ddc958bc4-2dqfc:1:6a9e414a39ae',
          'busy' => 0,
          'beat' => 1_621_443_630.1026807,
          'quiet' => 'false'
        ),
        Sidekiq::Process.new(
          'hostname' => 'virtual-bank-ui-sidekiq-high-7ddc958bc4-vskqn',
          'started_at' => 1_621_278_737.9591463,
          'pid' => 1,
          'tag' => 'app',
          'concurrency' => 4,
          'queues' => %w[high_priority default],
          'labels' => ['reliable'],
          'identity' => 'virtual-bank-ui-sidekiq-high-7ddc958bc4-vskqn:1:4fd3b9886a65',
          'busy' => 2,
          'beat' => 1_621_443_631.3395002,
          'quiet' => 'false'
        ),
        Sidekiq::Process.new(
          'hostname' => 'virtual-bank-ui-sidekiq-high-7ddc958bc4-xjwt6',
          'started_at' => 1_621_278_736.3673368,
          'pid' => 1,
          'tag' => 'app',
          'concurrency' => 4,
          'queues' => %w[high_priority default],
          'labels' => ['reliable'],
          'identity' => 'virtual-bank-ui-sidekiq-high-7ddc958bc4-xjwt6:1:ac02671870e9',
          'busy' => 0,
          'beat' => 1_621_443_630.9927886,
          'quiet' => 'false'
        )
      ]
    end
    let(:workers) do
      [
        ['virtual-bank-ui-sidekiq-6b84868fc8-q9nbh:1:dddae808973b',
         'ototdxvwl',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'SendBatchJob',
           'args' => [36_495],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => '4f00f112a79553aa250f5be2',
           'created_at' => 1_621_440_159.276964,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_392.524432
         },
         'run_at' => 1_621_464_485],
        ['virtual-bank-ui-sidekiq-6b84868fc8-q9nbh:1:dddae808973b',
         'ototdybr5',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'SendBatchJob',
           'args' => [36_502],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => 'f0b0d20fb821f53d09694bed',
           'created_at' => 1_621_440_159.0342908,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_370.10224
         },
         'run_at' => 1_621_457_899],
        ['virtual-bank-ui-sidekiq-6b84868fc8-q9nbh:1:dddae808973b',
         'ototdxj5p',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'SendBatchJob',
           'args' => [36_505],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => '8579191c7787b2130bbffe0b',
           'created_at' => 1_621_440_161.44905,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_221.2738369
         },
         'run_at' => 1_621_440_221],
        ['virtual-bank-ui-sidekiq-6b84868fc8-t5v6j:1:63598e6dbe42',
         'ox3iyb0et',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'CreateBatchJob',
           'args' => [36_494],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => '14abf8379ccc43577c8c0194',
           'created_at' => 1_621_440_159.9931056,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_209.887972
         },
         'run_at' => 1_621_440_210],
        ['virtual-bank-ui-sidekiq-6b84868fc8-t5v6j:1:63598e6dbe42',
         'ox3iybd69',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'CreateBatchJob',
           'args' => [36_503],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => '7700cd2f92de1ccf5cf77295',
           'created_at' => 1_621_440_159.80081,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_243.4718804
         },
         'run_at' => 1_621_440_243],
        ['virtual-bank-ui-sidekiq-high-7ddc958bc4-vskqn:1:4fd3b9886a65',
         'ox3iyakk9',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'SendBatchJob',
           'args' => [36_506],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => '3daef8a06eee1c0a749f926b',
           'created_at' => 1_621_440_161.1449542,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_437.636603
         },
         'run_at' => 1_621_440_437],
        ['virtual-bank-ui-sidekiq-high-7ddc958bc4-vskqn:1:4fd3b9886a65',
         'ox3iyaxbp',
         'queue' => 'high_priority',
         'payload' => {
           'class' => 'SendBatchJob',
           'args' => [36_512],
           'retry' => false,
           'queue' => 'high_priority',
           'jid' => '6eaca954ca071c6f576c2dd1',
           'created_at' => 1_621_440_161.8640628,
           'bid' => 'dYUbfmZuFVv2xg',
           'enqueued_at' => 1_621_440_343.5791998
         },
         'run_at' => 1_621_460_321]
      ]
    end
    let(:exp_output) do
      <<~OUT
        [  ] virtual-bank-ui-sidekiq-6b84868fc8-lrrhw ============================================
            [  ] e40e1157a14b : 0/4/0 ------------------------------------------------------------
                [  ] no workers found!
        [  ] virtual-bank-ui-sidekiq-6b84868fc8-q9nbh ============================================
            [  ] dddae808973b : 3/4/1 ------------------------------------------------------------
                [  ] ototdxvwl (H) 24m 1s     : SendBatchJob [36495]
                [  ] ototdybr5 (H) 2h 13m 47s : SendBatchJob [36502]
                [XX] ototdxj5p (H) 7h 8m 25s  : SendBatchJob [36505]
        [XX] virtual-bank-ui-sidekiq-6b84868fc8-t5v6j ============================================
            [XX] 63598e6dbe42 : 2/4/2 ------------------------------------------------------------
                [XX] ox3iyb0et (H) 7h 8m 36s  : CreateBatchJob [36494]
                [XX] ox3iybd69 (H) 7h 8m 3s   : CreateBatchJob [36503]
        [  ] virtual-bank-ui-sidekiq-high-7ddc958bc4-2dqfc =======================================
            [  ] 6a9e414a39ae : 0/4/0 ------------------------------------------------------------
                [  ] no workers found!
        [  ] virtual-bank-ui-sidekiq-high-7ddc958bc4-vskqn =======================================
            [  ] 4fd3b9886a65 : 2/4/1 ------------------------------------------------------------
                [XX] ox3iyakk9 (H) 7h 4m 49s  : SendBatchJob [36506]
                [  ] ox3iyaxbp (H) 1h 33m 25s : SendBatchJob [36512]
        [  ] virtual-bank-ui-sidekiq-high-7ddc958bc4-xjwt6 =======================================
            [  ] ac02671870e9 : 0/4/0 ------------------------------------------------------------
                [  ] no workers found!
      OUT
    end
    before do
      Sidekiq::ProcessSet.list processes
      Sidekiq::Workers.list workers
    end
    let(:result) { described_class.build }
    it 'builds a tree of hosts, processes and workers' do
      Timecop.travel(generation_time) do
        expect { result }.to_not raise_error

        result.report

        expect { result.report }.to output(exp_output).to_stdout

        hostname = 'virtual-bank-ui-sidekiq-6b84868fc8-q9nbh'
        sel_host = result.hosts[hostname]
        expect(sel_host.inspect).to eq %(#<FatherlyAdvice::SidekiqHelpers::Host hostname="#{hostname}">)

        proc_id = 'dddae808973b'
        proc_identity = %(#{hostname}:1:#{proc_id})
        sel_process = sel_host.processes[proc_identity]
        expect(sel_process.inspect).to eq %(#<FatherlyAdvice::SidekiqHelpers::Process hostname="#{hostname}" id="#{proc_id}">)

        worker_id = 'ototdxj5p'
        sel_worker = sel_process.workers[worker_id]
        expect(sel_worker.inspect).to eq %(#<FatherlyAdvice::SidekiqHelpers::Worker thread_id="#{worker_id}" stuck=true time_ago="7h 8m 25s" klass="SendBatchJob">)
      end
    end
  end
end
